import AcmePlatform
import Foundation

extension Referrals {
    /// Moves pending slot targets through their life cycle and keeps a journal of what it did.
    final class PendingSlotTargetService {
        var store: any PendingSlotTargetStore
        var validator: PendingSlotTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingSlotTargetEngine

        init(store: any PendingSlotTargetStore, validator: PendingSlotTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingSlotTargetEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending slot target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingSlotTargetStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending slot target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingSlotTargetStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending slot target \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newPendingSlotTargetService(_ store: any PendingSlotTargetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingSlotTargetService {
        return PendingSlotTargetService(
            store: store,
            validator: defaultPendingSlotTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingSlotTargetEngine(flags)
        )
    }
}
