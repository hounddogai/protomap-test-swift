import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves recall quotas through their life cycle and keeps a journal of what it did.
    final class RecallQuotaManager {
        var store: any RecallQuotaStore
        var validator: RecallQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RecallQuotaEngine

        init(store: any RecallQuotaStore, validator: RecallQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RecallQuotaEngine) {
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
                throw Kit.Failure("recall quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RecallQuotaStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RecallQuotaStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall quota \(code) not found")
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

    static func newRecallQuotaManager(_ store: any RecallQuotaStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RecallQuotaManager {
        return RecallQuotaManager(
            store: store,
            validator: defaultRecallQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultRecallQuotaEngine(flags)
        )
    }
}
