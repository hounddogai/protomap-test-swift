@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryStrictDischargePlanPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.StrictDischargePlanPolicyStore = BedManagement.newMemoryStrictDischargePlanPolicyStore()
        let item = BedManagement.newStrictDischargePlanPolicy("code-834", name: "name-231")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
