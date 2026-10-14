@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryLenientIsolationTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.LenientIsolationTemplateStore = BedManagement.newMemoryLenientIsolationTemplateStore()
        let item = BedManagement.newLenientIsolationTemplate("code-605", title: "title-589")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
