@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAcuityPlanEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AcuityPlanEntryStore = Staffing.newMemoryAcuityPlanEntryStore()
        let item = Staffing.newAcuityPlanEntry("code-818", name: "name-553")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
