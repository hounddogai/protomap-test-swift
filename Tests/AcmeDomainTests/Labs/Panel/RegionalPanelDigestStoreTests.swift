@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRegionalPanelDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RegionalPanelDigestStore = Labs.newMemoryRegionalPanelDigestStore()
        let item = Labs.newRegionalPanelDigest("code-148", title: "title-871")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
