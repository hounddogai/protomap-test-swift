@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDischargePlanThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DischargePlanThresholdStore = BedManagement.newMemoryDischargePlanThresholdStore()
        let item = BedManagement.newDischargePlanThreshold("code-358", name: "name-269")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
