import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves global care protocol digests through their life cycle and keeps a journal of what it did.
    final class GlobalCareProtocolDigestService {
        var store: any GlobalCareProtocolDigestStore
        var validator: GlobalCareProtocolDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalCareProtocolDigestEngine

        init(store: any GlobalCareProtocolDigestStore, validator: GlobalCareProtocolDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalCareProtocolDigestEngine) {
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
                throw Kit.Failure("global care protocol digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalCareProtocolDigestStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global care protocol digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalCareProtocolDigestStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global care protocol digest \(code) not found")
            }
            let result = engine.price(item)
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

    static func newGlobalCareProtocolDigestService(_ store: any GlobalCareProtocolDigestStore, clock: any Kit.Clocks.Clock) -> GlobalCareProtocolDigestService {
        return GlobalCareProtocolDigestService(
            store: store,
            validator: defaultGlobalCareProtocolDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalCareProtocolDigestEngine()
        )
    }
}
