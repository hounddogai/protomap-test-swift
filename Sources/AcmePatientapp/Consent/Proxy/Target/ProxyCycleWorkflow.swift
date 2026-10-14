import AcmePlatform
import Foundation

extension Consent {
    /// Moves proxy cycles through their life cycle and keeps a journal of what it did.
    final class ProxyCycleDesk {
        var store: any ProxyCycleStore
        var validator: ProxyCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ProxyCycleEngine

        init(store: any ProxyCycleStore, validator: ProxyCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ProxyCycleEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProxyCycleStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProxyCycleStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy cycle \(code) not found")
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

    static func newProxyCycleDesk(_ store: any ProxyCycleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ProxyCycleDesk {
        return ProxyCycleDesk(
            store: store,
            validator: defaultProxyCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultProxyCycleEngine(flags)
        )
    }
}
