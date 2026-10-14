import AcmePlatform
import Foundation

extension Labs {
    /// Moves reference range cycles through their life cycle and keeps a journal of what it did.
    final class ReferenceRangeCycleManager {
        var store: any ReferenceRangeCycleStore
        var validator: ReferenceRangeCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReferenceRangeCycleEngine

        init(store: any ReferenceRangeCycleStore, validator: ReferenceRangeCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReferenceRangeCycleEngine) {
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
                throw Kit.Failure("reference range cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferenceRangeCycleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferenceRangeCycleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range cycle \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newReferenceRangeCycleManager(_ store: any ReferenceRangeCycleStore, clock: any Kit.Clocks.Clock) -> ReferenceRangeCycleManager {
        return ReferenceRangeCycleManager(
            store: store,
            validator: defaultReferenceRangeCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultReferenceRangeCycleEngine()
        )
    }
}
