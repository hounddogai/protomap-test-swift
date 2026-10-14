import AcmePlatform
import Foundation

extension Consent {
    /// Moves lenient disclosure milestones through their life cycle and keeps a journal of what it did.
    final class LenientDisclosureMilestoneManager {
        var store: any LenientDisclosureMilestoneStore
        var validator: LenientDisclosureMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientDisclosureMilestoneEngine

        init(store: any LenientDisclosureMilestoneStore, validator: LenientDisclosureMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientDisclosureMilestoneEngine) {
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
                throw Kit.Failure("lenient disclosure milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientDisclosureMilestoneStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient disclosure milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientDisclosureMilestoneStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient disclosure milestone \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newLenientDisclosureMilestoneManager(_ store: any LenientDisclosureMilestoneStore, clock: any Kit.Clocks.Clock) -> LenientDisclosureMilestoneManager {
        return LenientDisclosureMilestoneManager(
            store: store,
            validator: defaultLenientDisclosureMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientDisclosureMilestoneEngine()
        )
    }
}
