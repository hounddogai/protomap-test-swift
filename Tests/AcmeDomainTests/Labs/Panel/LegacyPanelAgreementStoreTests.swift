@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLegacyPanelAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LegacyPanelAgreementStore = Labs.newMemoryLegacyPanelAgreementStore()
        let item = Labs.newLegacyPanelAgreement("code-538", name: "name-793")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
