@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryWeightedCredentialDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.WeightedCredentialDigestStore = Staffing.newMemoryWeightedCredentialDigestStore()
        let item = Staffing.newWeightedCredentialDigest("code-595", label: "label-22")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
