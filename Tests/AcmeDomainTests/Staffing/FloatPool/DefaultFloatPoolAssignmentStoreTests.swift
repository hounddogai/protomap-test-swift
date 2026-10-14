@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryDefaultFloatPoolAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.DefaultFloatPoolAssignmentStore = Staffing.newMemoryDefaultFloatPoolAssignmentStore()
        let item = Staffing.newDefaultFloatPoolAssignment("code-200", name: "name-100")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
