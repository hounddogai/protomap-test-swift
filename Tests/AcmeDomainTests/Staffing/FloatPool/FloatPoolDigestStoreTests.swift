@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFloatPoolDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FloatPoolDigestStore = Staffing.newMemoryFloatPoolDigestStore()
        let item = Staffing.newFloatPoolDigest("code-877", label: "label-5")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
