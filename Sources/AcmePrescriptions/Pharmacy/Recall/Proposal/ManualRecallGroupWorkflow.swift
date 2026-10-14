import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves manual recall groups through their life cycle and keeps a journal of what it did.
    final class ManualRecallGroupService {
        var store: any ManualRecallGroupStore
        var validator: ManualRecallGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualRecallGroupEngine

        init(store: any ManualRecallGroupStore, validator: ManualRecallGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualRecallGroupEngine) {
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
                throw Kit.Failure("manual recall group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualRecallGroupStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual recall group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualRecallGroupStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual recall group \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newManualRecallGroupService(_ store: any ManualRecallGroupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ManualRecallGroupService {
        return ManualRecallGroupService(
            store: store,
            validator: defaultManualRecallGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualRecallGroupEngine(flags)
        )
    }
}
