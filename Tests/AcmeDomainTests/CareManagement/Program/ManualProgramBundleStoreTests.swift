@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryManualProgramBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ManualProgramBundleStore = CareManagement.newMemoryManualProgramBundleStore()
        let item = CareManagement.newManualProgramBundle("code-539", title: "title-162")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
