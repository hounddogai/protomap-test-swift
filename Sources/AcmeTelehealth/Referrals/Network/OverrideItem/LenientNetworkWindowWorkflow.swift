import AcmePlatform
import Foundation

extension Referrals {
    /// Moves lenient network windows through their life cycle and keeps a journal of what it did.
    final class LenientNetworkWindowCoordinator {
        var store: any LenientNetworkWindowStore
        var validator: LenientNetworkWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientNetworkWindowEngine

        init(store: any LenientNetworkWindowStore, validator: LenientNetworkWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientNetworkWindowEngine) {
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
                throw Kit.Failure("lenient network window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientNetworkWindowStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient network window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientNetworkWindowStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient network window \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newLenientNetworkWindowCoordinator(_ store: any LenientNetworkWindowStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LenientNetworkWindowCoordinator {
        return LenientNetworkWindowCoordinator(
            store: store,
            validator: defaultLenientNetworkWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientNetworkWindowEngine(flags)
        )
    }
}
