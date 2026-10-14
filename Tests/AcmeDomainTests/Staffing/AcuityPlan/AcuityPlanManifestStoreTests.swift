@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAcuityPlanManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AcuityPlanManifestStore = Staffing.newMemoryAcuityPlanManifestStore()
        let item = Staffing.newAcuityPlanManifest("code-358", name: "name-723")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
