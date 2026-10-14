@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryManualRecallClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.ManualRecallClaimStore = Pharmacy.newMemoryManualRecallClaimStore()
        let item = Pharmacy.newManualRecallClaim("code-709", title: "title-443")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
