@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryPrimaryCredentialEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.PrimaryCredentialEstimateStore = Staffing.newMemoryPrimaryCredentialEstimateStore()
        let item = Staffing.newPrimaryCredentialEstimate("code-607", title: "title-114")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
