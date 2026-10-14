@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFloatPoolWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FloatPoolWindowStore = Staffing.newMemoryFloatPoolWindowStore()
        let item = Staffing.newFloatPoolWindow("code-823", label: "label-929")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
