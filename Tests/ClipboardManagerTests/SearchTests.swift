import Testing
@testable import ClipboardManagerCore

struct SearchTests {
    @Test func searchIsCaseInsensitive() {
        let store = ClipboardHistoryStore()
        store.add(text: "Spring Boot")
        store.add(text: "Java")
        store.add(text: "Spring Security")
        let results = ClipboardSearchEngine().search(query: "SPRING", items: store.items)
        #expect(results.count == 2)
    }

    @Test func emptySearchReturnsAll() {
        let store = ClipboardHistoryStore()
        store.add(text: "One")
        store.add(text: "Two")
        #expect(ClipboardSearchEngine().search(query: "", items: store.items).count == 2)
    }
}
