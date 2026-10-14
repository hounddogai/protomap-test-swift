@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySeasonalOvertimeDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SeasonalOvertimeDigestStore = Staffing.newMemorySeasonalOvertimeDigestStore()
        let item = Staffing.newSeasonalOvertimeDigest("code-788", name: "name-810")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
