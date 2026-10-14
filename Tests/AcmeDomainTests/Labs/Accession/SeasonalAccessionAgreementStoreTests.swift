@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySeasonalAccessionAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SeasonalAccessionAgreementStore = Labs.newMemorySeasonalAccessionAgreementStore()
        let item = Labs.newSeasonalAccessionAgreement("code-457", title: "title-270")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
