@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCappedAccessionWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CappedAccessionWindowStore = Labs.newMemoryCappedAccessionWindowStore()
        let item = Labs.newCappedAccessionWindow("code-182", title: "title-127")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
