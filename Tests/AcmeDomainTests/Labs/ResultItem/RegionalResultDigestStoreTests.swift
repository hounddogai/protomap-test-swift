@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRegionalResultDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RegionalResultDigestStore = Labs.newMemoryRegionalResultDigestStore()
        let item = Labs.newRegionalResultDigest("code-406", label: "label-858")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
