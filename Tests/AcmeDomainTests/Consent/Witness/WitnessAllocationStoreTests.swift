@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessAllocationStore = Consent.newMemoryWitnessAllocationStore()
        let item = Consent.newWitnessAllocation("code-728", title: "title-212")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
