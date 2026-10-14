import AcmePlatform
import Foundation

extension Referrals {
    /// Moves default network windows through their life cycle and keeps a journal of what it did.
    final class DefaultNetworkWindowManager {
        var store: any DefaultNetworkWindowStore
        var validator: DefaultNetworkWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultNetworkWindowEngine

        init(store: any DefaultNetworkWindowStore, validator: DefaultNetworkWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultNetworkWindowEngine) {
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
                throw Kit.Failure("default network window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultNetworkWindowStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default network window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultNetworkWindowStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default network window \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newDefaultNetworkWindowManager(_ store: any DefaultNetworkWindowStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DefaultNetworkWindowManager {
        return DefaultNetworkWindowManager(
            store: store,
            validator: defaultDefaultNetworkWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultNetworkWindowEngine(flags)
        )
    }
}
