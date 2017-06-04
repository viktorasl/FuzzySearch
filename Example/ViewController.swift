//
//  ViewController.swift
//  Example
//
//  Created by Viktoras Laukevičius on 04/06/2017.
//  Copyright (c) 2017 Viktoras Laukevičius. All rights reserved.
//

import UIKit
import FuzzySearch

struct Country {
    let name: String
    let native: String
}

extension Country: FuzzySearchable {
    var fuzzyStringToMatch: String {
        return name
    }
}

struct SearchResultCountry {
    let country: Country
    let highlightedParts: [NSRange]
}

final class FuzzySearchOperation: Operation {
    
    let countries: [Country]
    let searchText: String
    let completion: ([SearchResultCountry]) -> Void
    
    init(countries: [Country], searchText: String, completion: @escaping ([SearchResultCountry]) -> Void) {
        self.countries = countries
        self.searchText = searchText
        self.completion = completion
    }
    
    override func main() {
        let results = countries.fuzzyMatch(searchText).map { SearchResultCountry(country: $0.item, highlightedParts: $0.result.parts) }
        DispatchQueue.main.sync {
            if !self.isCancelled {
                self.completion(results)
            }
        }
    }
}

class ViewController: UITableViewController {

    var countries: [Country]!
    var shownCountries: [SearchResultCountry] = []
    let searchQueue = OperationQueue()
    var searchController: UISearchController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchController = UISearchController(searchResultsController: nil)
        
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        tableView.tableHeaderView = searchController.searchBar
        
        let jsonURL = Bundle.main.url(forResource: "countries", withExtension: "json")
        let jsonData = try! Data(contentsOf: jsonURL!, options: .mappedIfSafe)
        let contents = try! JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as! [String : Any]
        
        let countriesContents = contents["countries"] as! [String : Any]
        countries = countriesContents.map { (_, v) -> Country in
            let countryContents = v as! [String : String]
            return Country(
                name: countryContents["name"]!,
                native: countryContents["native"]!
            )
        }
        shownCountries = countries.map { SearchResultCountry(country: $0, highlightedParts: []) }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shownCountries.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CountryCell", for: indexPath)
        let searchResult = shownCountries[indexPath.row]

        let attrStr = NSMutableAttributedString(string: searchResult.country.name)
        attrStr.addAttributes([
            NSFontAttributeName: UIFont.systemFont(ofSize: 17),
            NSForegroundColorAttributeName: UIColor.black
        ], range: NSRange(location: 0, length: searchResult.country.name.characters.count))
        searchResult.highlightedParts.forEach {
            attrStr.addAttributes([
                NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17),
                NSForegroundColorAttributeName: UIColor.red
            ], range: $0)
        }
        
        cell.textLabel?.attributedText = attrStr
        cell.detailTextLabel?.text = searchResult.country.native
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchQueue.cancelAllOperations()
        
        let trimmedSearchText = (searchController.searchBar.text ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !trimmedSearchText.isEmpty else {
            shownCountries = countries.map { SearchResultCountry(country: $0, highlightedParts: []) }
            tableView.reloadData()
            return
        }
        
        let searchOp = FuzzySearchOperation(countries: countries, searchText: trimmedSearchText) { [weak self] in
            guard let `self` = self else { return }
            self.shownCountries = $0
            self.tableView.reloadData()
        }
        searchQueue.addOperation(searchOp)
    }
}
