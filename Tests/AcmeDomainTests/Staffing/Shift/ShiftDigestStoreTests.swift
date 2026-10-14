@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryShiftDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ShiftDigestStore = Staffing.newMemoryShiftDigestStore()
        let item = Staffing.newShiftDigest("code-928", label: "label-132")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
