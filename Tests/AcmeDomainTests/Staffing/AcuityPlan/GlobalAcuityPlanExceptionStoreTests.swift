@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryGlobalAcuityPlanExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.GlobalAcuityPlanExceptionStore = Staffing.newMemoryGlobalAcuityPlanExceptionStore()
        let item = Staffing.newGlobalAcuityPlanException("code-267", title: "title-829")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
