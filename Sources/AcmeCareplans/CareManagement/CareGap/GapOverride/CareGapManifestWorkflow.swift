import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves care gap manifests through their life cycle and keeps a journal of what it did.
    final class CareGapManifestWorkflow {
        var store: any CareGapManifestStore
        var validator: CareGapManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CareGapManifestStore, validator: CareGapManifestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareGapManifestStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareGapManifestStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newCareGapManifestWorkflow(_ store: any CareGapManifestStore, clock: any Kit.Clocks.Clock) -> CareGapManifestWorkflow {
        return CareGapManifestWorkflow(
            store: store,
            validator: defaultCareGapManifestValidator(),
            clock: clock,
            journal: []
        )
    }
}
