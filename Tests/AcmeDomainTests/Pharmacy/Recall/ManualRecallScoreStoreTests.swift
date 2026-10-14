@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryManualRecallScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.ManualRecallScoreStore = Pharmacy.newMemoryManualRecallScoreStore()
        let item = Pharmacy.newManualRecallScore("code-514", title: "title-225")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
