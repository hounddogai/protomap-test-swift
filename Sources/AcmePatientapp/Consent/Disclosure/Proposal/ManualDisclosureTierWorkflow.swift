import AcmePlatform
import Foundation

extension Consent {
    /// Moves manual disclosure tiers through their life cycle and keeps a journal of what it did.
    final class ManualDisclosureTierWorkflow {
        var store: any ManualDisclosureTierStore
        var validator: ManualDisclosureTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualDisclosureTierEngine

        init(store: any ManualDisclosureTierStore, validator: ManualDisclosureTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualDisclosureTierEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual disclosure tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualDisclosureTierStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual disclosure tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualDisclosureTierStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual disclosure tier \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newManualDisclosureTierWorkflow(_ store: any ManualDisclosureTierStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ManualDisclosureTierWorkflow {
        return ManualDisclosureTierWorkflow(
            store: store,
            validator: defaultManualDisclosureTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualDisclosureTierEngine(flags)
        )
    }
}
