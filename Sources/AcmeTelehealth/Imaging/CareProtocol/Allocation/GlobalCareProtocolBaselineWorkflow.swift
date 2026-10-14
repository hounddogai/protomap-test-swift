import AcmePlatform
import Foundation

extension Imaging {
    /// Moves global care protocol baselines through their life cycle and keeps a journal of what it did.
    final class GlobalCareProtocolBaselineService {
        var store: any GlobalCareProtocolBaselineStore
        var validator: GlobalCareProtocolBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalCareProtocolBaselineEngine

        init(store: any GlobalCareProtocolBaselineStore, validator: GlobalCareProtocolBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalCareProtocolBaselineEngine) {
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
                throw Kit.Failure("global care protocol baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalCareProtocolBaselineStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global care protocol baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalCareProtocolBaselineStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global care protocol baseline \(code) not found")
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
                if item.endsAt > cutoff {
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

    static func newGlobalCareProtocolBaselineService(_ store: any GlobalCareProtocolBaselineStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GlobalCareProtocolBaselineService {
        return GlobalCareProtocolBaselineService(
            store: store,
            validator: defaultGlobalCareProtocolBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalCareProtocolBaselineEngine(flags)
        )
    }
}
