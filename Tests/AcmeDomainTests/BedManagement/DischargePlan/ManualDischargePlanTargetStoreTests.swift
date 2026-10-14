@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryManualDischargePlanTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ManualDischargePlanTargetStore = BedManagement.newMemoryManualDischargePlanTargetStore()
        let item = BedManagement.newManualDischargePlanTarget("code-923", label: "label-265")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
