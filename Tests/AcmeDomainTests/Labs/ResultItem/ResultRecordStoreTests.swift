@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultRecordStore = Labs.newMemoryResultRecordStore()
        let item = Labs.newResultRecord("code-777", label: "label-506")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
