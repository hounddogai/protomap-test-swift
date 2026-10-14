@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallScoreStore = Pharmacy.newMemoryRecallScoreStore()
        let item = Pharmacy.newRecallScore("code-220", label: "label-696")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
