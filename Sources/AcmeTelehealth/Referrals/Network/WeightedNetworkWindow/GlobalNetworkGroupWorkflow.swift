import AcmePlatform
import Foundation

extension Referrals {
    /// Moves global network groups through their life cycle and keeps a journal of what it did.
    final class GlobalNetworkGroupManager {
        var store: any GlobalNetworkGroupStore
        var validator: GlobalNetworkGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalNetworkGroupEngine

        init(store: any GlobalNetworkGroupStore, validator: GlobalNetworkGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalNetworkGroupEngine) {
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
                throw Kit.Failure("global network group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalNetworkGroupStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global network group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalNetworkGroupStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global network group \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newGlobalNetworkGroupManager(_ store: any GlobalNetworkGroupStore, clock: any Kit.Clocks.Clock) -> GlobalNetworkGroupManager {
        return GlobalNetworkGroupManager(
            store: store,
            validator: defaultGlobalNetworkGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalNetworkGroupEngine()
        )
    }
}
