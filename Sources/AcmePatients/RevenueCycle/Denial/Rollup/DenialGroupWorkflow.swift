import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves denial groups through their life cycle and keeps a journal of what it did.
    final class DenialGroupWorkflow {
        var store: any DenialGroupStore
        var validator: DenialGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DenialGroupEngine

        init(store: any DenialGroupStore, validator: DenialGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DenialGroupEngine) {
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
                throw Kit.Failure("denial group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DenialGroupStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DenialGroupStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial group \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newDenialGroupWorkflow(_ store: any DenialGroupStore, clock: any Kit.Clocks.Clock) -> DenialGroupWorkflow {
        return DenialGroupWorkflow(
            store: store,
            validator: defaultDenialGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultDenialGroupEngine()
        )
    }
}
