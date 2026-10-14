@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDischargePlanTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DischargePlanTargetStore = BedManagement.newMemoryDischargePlanTargetStore()
        let item = BedManagement.newDischargePlanTarget("code-585", name: "name-894")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
