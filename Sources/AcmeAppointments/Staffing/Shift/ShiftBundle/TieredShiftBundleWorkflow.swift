import AcmePlatform
import Foundation

extension Staffing {
    /// Moves tiered shift bundles through their life cycle and keeps a journal of what it did.
    final class TieredShiftBundleWorkflow {
        var store: any TieredShiftBundleStore
        var validator: TieredShiftBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TieredShiftBundleStore, validator: TieredShiftBundleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered shift bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredShiftBundleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered shift bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredShiftBundleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newTieredShiftBundleWorkflow(_ store: any TieredShiftBundleStore, clock: any Kit.Clocks.Clock) -> TieredShiftBundleWorkflow {
        return TieredShiftBundleWorkflow(
            store: store,
            validator: defaultTieredShiftBundleValidator(),
            clock: clock,
            journal: []
        )
    }
}
