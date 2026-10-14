import AcmePlatform
import Foundation

extension Referrals {
    /// Moves adaptive follow up notices through their life cycle and keeps a journal of what it did.
    final class AdaptiveFollowUpNoticeDesk {
        var store: any AdaptiveFollowUpNoticeStore
        var validator: AdaptiveFollowUpNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveFollowUpNoticeEngine

        init(store: any AdaptiveFollowUpNoticeStore, validator: AdaptiveFollowUpNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveFollowUpNoticeEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive follow up notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveFollowUpNoticeStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive follow up notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveFollowUpNoticeStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive follow up notice \(code) not found")
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

    static func newAdaptiveFollowUpNoticeDesk(_ store: any AdaptiveFollowUpNoticeStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AdaptiveFollowUpNoticeDesk {
        return AdaptiveFollowUpNoticeDesk(
            store: store,
            validator: defaultAdaptiveFollowUpNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveFollowUpNoticeEngine(flags)
        )
    }
}
