import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves manual program bundles through their life cycle and keeps a journal of what it did.
    final class ManualProgramBundleService {
        var store: any ManualProgramBundleStore
        var validator: ManualProgramBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ManualProgramBundleStore, validator: ManualProgramBundleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("manual program bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualProgramBundleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual program bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualProgramBundleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newManualProgramBundleService(_ store: any ManualProgramBundleStore, clock: any Kit.Clocks.Clock) -> ManualProgramBundleService {
        return ManualProgramBundleService(
            store: store,
            validator: defaultManualProgramBundleValidator(),
            clock: clock,
            journal: []
        )
    }
}
