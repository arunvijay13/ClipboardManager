import Testing
@testable import ClipboardManagerCore

struct HistoryStoreTests {
    @Test func addsText() {
        let store = ClipboardHistoryStore()
        store.add(text: "Hello")
        #expect(store.items.count == 1)
        #expect(store.items[0].text == "Hello")
    }

    @Test func duplicateTextIsRemoved() {
        let store = ClipboardHistoryStore()
        store.add(text: "Hello")
        store.add(text: "Hello")
        #expect(store.items.count == 1)
    }

    @Test func duplicateMovesToTop() {
        let store = ClipboardHistoryStore()
        store.add(text: "First")
        store.add(text: "Second")
        store.add(text: "First")
        #expect(store.items.map(\.text) == ["First", "Second"])
    }

    @Test func deleteWorks() {
        let store = ClipboardHistoryStore()
        store.add(text: "Hello")
        store.delete(id: store.items[0].id)
        #expect(store.items.isEmpty)
    }

    @Test func clearWorks() {
        let store = ClipboardHistoryStore()
        store.add(text: "One")
        store.add(text: "Two")
        store.clear()
        #expect(store.items.isEmpty)
    }
}
