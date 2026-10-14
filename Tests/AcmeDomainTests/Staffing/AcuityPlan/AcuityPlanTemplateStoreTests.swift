@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAcuityPlanTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AcuityPlanTemplateStore = Staffing.newMemoryAcuityPlanTemplateStore()
        let item = Staffing.newAcuityPlanTemplate("code-713", label: "label-301")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
