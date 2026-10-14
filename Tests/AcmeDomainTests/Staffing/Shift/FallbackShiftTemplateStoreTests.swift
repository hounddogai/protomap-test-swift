@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFallbackShiftTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FallbackShiftTemplateStore = Staffing.newMemoryFallbackShiftTemplateStore()
        let item = Staffing.newFallbackShiftTemplate("code-637", label: "label-316")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
