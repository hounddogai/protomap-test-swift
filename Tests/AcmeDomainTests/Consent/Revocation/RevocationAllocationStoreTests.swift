@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationAllocationStore = Consent.newMemoryRevocationAllocationStore()
        let item = Consent.newRevocationAllocation("code-654", label: "label-477")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
