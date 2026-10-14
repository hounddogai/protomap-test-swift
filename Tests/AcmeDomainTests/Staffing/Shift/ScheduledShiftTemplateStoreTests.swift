@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryScheduledShiftTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ScheduledShiftTemplateStore = Staffing.newMemoryScheduledShiftTemplateStore()
        let item = Staffing.newScheduledShiftTemplate("code-846", name: "name-417")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
