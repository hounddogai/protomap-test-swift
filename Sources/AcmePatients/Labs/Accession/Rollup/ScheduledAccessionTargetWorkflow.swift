import AcmePlatform
import Foundation

extension Labs {
    /// Moves scheduled accession targets through their life cycle and keeps a journal of what it did.
    final class ScheduledAccessionTargetService {
        var store: any ScheduledAccessionTargetStore
        var validator: ScheduledAccessionTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledAccessionTargetEngine

        init(store: any ScheduledAccessionTargetStore, validator: ScheduledAccessionTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledAccessionTargetEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled accession target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledAccessionTargetStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled accession target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledAccessionTargetStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled accession target \(code) not found")
            }
            let result = engine.price(item)
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

    static func newScheduledAccessionTargetService(_ store: any ScheduledAccessionTargetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledAccessionTargetService {
        return ScheduledAccessionTargetService(
            store: store,
            validator: defaultScheduledAccessionTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledAccessionTargetEngine(flags)
        )
    }
}
