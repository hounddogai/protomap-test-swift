import AcmePlatform
import Foundation

extension Referrals {
    /// Moves closure overrides through their life cycle and keeps a journal of what it did.
    final class ClosureOverrideService {
        var store: any ClosureOverrideStore
        var validator: ClosureOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClosureOverrideEngine

        init(store: any ClosureOverrideStore, validator: ClosureOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClosureOverrideEngine) {
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
                throw Kit.Failure("closure override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClosureOverrideStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClosureOverrideStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure override \(code) not found")
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

    static func newClosureOverrideService(_ store: any ClosureOverrideStore, clock: any Kit.Clocks.Clock) -> ClosureOverrideService {
        return ClosureOverrideService(
            store: store,
            validator: defaultClosureOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultClosureOverrideEngine()
        )
    }
}
