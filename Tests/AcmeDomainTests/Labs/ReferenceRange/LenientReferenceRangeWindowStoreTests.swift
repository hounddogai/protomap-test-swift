@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLenientReferenceRangeWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LenientReferenceRangeWindowStore = Labs.newMemoryLenientReferenceRangeWindowStore()
        let item = Labs.newLenientReferenceRangeWindow("code-174", name: "name-629")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
