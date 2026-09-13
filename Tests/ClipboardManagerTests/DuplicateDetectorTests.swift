import Testing
@testable import ClipboardManagerCore

struct DuplicateDetectorTests {
    @Test func detectsDuplicate() {
        let store = ClipboardHistoryStore()
        store.add(text: "Hello")
        #expect(DuplicateDetector().findDuplicate(text: "Hello", in: store.items) != nil)
    }

    @Test func differentTextIsNotDuplicate() {
        let store = ClipboardHistoryStore()
        store.add(text: "Hello")
        #expect(DuplicateDetector().findDuplicate(text: "World", in: store.items) == nil)
    }
}
