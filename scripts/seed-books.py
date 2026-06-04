#!/usr/bin/env python3
"""Seed book entities in the vault from the book catalog Excel file."""

import os
import re
import openpyxl
from datetime import date

VAULT = os.path.expanduser(
    "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT"
)
ENTITIES_DIR = os.path.join(VAULT, "wiki", "entities")
TODAY = date.today().isoformat()

BOOK_DATA = {
    "The Biggest Ideas in the Universe": {
        "domains": ["physics", "science", "first-principles"],
        "hint": "When Santiago needs physics intuition, fundamental forces, or scientific reasoning about how the universe works.",
        "thesis": "The deepest ideas in physics — relativity, quantum mechanics, geometry — are accessible through careful reasoning without advanced math. Understanding the universe's operating system sharpens thinking about any complex system.",
    },
    "Believe in People": {
        "domains": ["management", "culture", "libertarianism"],
        "hint": "When thinking about organizational culture, bottom-up empowerment, or principled management at scale.",
        "thesis": "Societies and organizations thrive when individuals are empowered to contribute and innovate, not when controlled top-down. The same market principles that create prosperity apply inside companies.",
    },
    "Investing: The Last Liberal Art (2nd ed.)": {
        "domains": ["investing", "mental-models", "cross-domain"],
        "hint": "When connecting insights across disciplines to investing decisions, or when seeking cross-domain analogies for business strategy.",
        "thesis": "Great investing requires a latticework of mental models drawn from physics, biology, psychology, philosophy, and literature. Narrow financial analysis misses the patterns that compound returns.",
    },
    "Don't Shoot the Dog!": {
        "domains": ["behavior", "psychology", "management", "training"],
        "hint": "When designing incentive systems, managing people, or understanding why behavior change fails. Operant conditioning applied to real life.",
        "thesis": "All behavior is shaped by reinforcement. Positive reinforcement is more effective than punishment for lasting change. Understanding reinforcement schedules explains why people (and organizations) do what they do.",
    },
    "HBR Guide to Buying a Small Business": {
        "domains": ["acquisition", "M&A", "small-business", "search-fund"],
        "hint": "When evaluating acquisition targets, structuring small business deals, or thinking about buy-vs-build decisions.",
        "thesis": "Buying an existing small business is often a better path to entrepreneurship than starting from scratch. The key is finding enduringly profitable businesses with owner-dependent operations you can systematize.",
    },
    "The Selfish Gene": {
        "domains": ["evolution", "biology", "game-theory", "first-principles"],
        "hint": "When reasoning about incentive alignment, competition, cooperation, or why systems evolve the way they do. Gene-level selection explains organizational behavior.",
        "thesis": "Evolution operates at the gene level, not the individual or species level. Organisms are survival machines built by genes to propagate themselves. This reframes cooperation, altruism, and competition as gene-strategy outcomes.",
    },
    "The Meme Machine": {
        "domains": ["evolution", "culture", "memetics", "marketing"],
        "hint": "When thinking about idea propagation, viral marketing, cultural evolution, or why some ideas spread and others die.",
        "thesis": "Ideas (memes) evolve by the same mechanism as genes — variation, selection, replication. Human culture is a second replicator system. Understanding memetic selection explains advertising, religion, and viral content.",
    },
    "How to Make a Few Billion Dollars": {
        "domains": ["consolidation", "M&A", "leadership", "operations", "scaling"],
        "hint": "When evaluating roll-up opportunities, consolidation plays, or scaling through acquisition. Direct playbook for pest control consolidation and any industry fragmentation thesis.",
        "thesis": "Massive wealth is built by identifying fragmented industries ripe for consolidation, acquiring at reasonable multiples, installing operational excellence, and compounding through scale advantages. Hire A-players, set clear metrics, move fast.",
    },
    "The Book of Elon": {
        "domains": ["entrepreneurship", "vision", "first-principles", "biography"],
        "hint": "When thinking about audacious goals, manufacturing thinking, or first-principles reasoning applied to seemingly impossible problems.",
        "thesis": "Elon Musk's thinking distilled — first principles over analogies, manufacturing as competitive advantage, mission-driven urgency, and the willingness to absorb personal risk for civilizational bets.",
    },
    "El Corazon es un Resorte": {
        "domains": ["philosophy", "literature", "Mexican-culture"],
        "hint": "When reflecting on emotional resilience, Mexican philosophical tradition, or the tension between rationality and feeling.",
        "thesis": "The heart springs back. A philosophical exploration of resilience, emotion, and meaning through a Mexican intellectual lens.",
        "aliases": ["El Corazón es un Resorte"],
    },
    "Measure What Matters": {
        "domains": ["OKRs", "management", "goal-setting", "operations"],
        "hint": "When setting goals for any business, implementing OKRs, or aligning team effort with strategic objectives.",
        "thesis": "OKRs (Objectives and Key Results) drive alignment and accountability at scale. What you measure shapes what you achieve. Ambitious goals with measurable results compound organizational performance.",
    },
    "Love & Math": {
        "domains": ["mathematics", "beauty", "first-principles"],
        "hint": "When seeking the deep structure beneath surface complexity, or when math intuition could unlock a business or technical insight.",
        "thesis": "Mathematics reveals hidden patterns and symmetries in nature. The beauty of math isn't abstract — it's the universe's source code. Loving the quest for understanding is the real lesson.",
    },
    "What Is Intelligence?": {
        "domains": ["AI", "cognition", "intelligence", "technology"],
        "hint": "When reasoning about AI capabilities, machine intelligence, or the nature of human vs artificial cognition.",
        "thesis": "Intelligence is not a single faculty but an emergent property of information processing. Understanding what intelligence actually is — beyond the hype — shapes how we build and deploy AI systems.",
    },
    "The Clockwork Universe": {
        "domains": ["science-history", "physics", "enlightenment"],
        "hint": "When thinking about how scientific revolutions happen, or how understanding mechanics changed how we see everything from physics to economics.",
        "thesis": "The Scientific Revolution revealed a universe governed by mathematical laws. Newton, Leibniz, and their contemporaries replaced mysticism with mechanism — a worldview shift that birthed modern science and rational enterprise.",
    },
    "Against the Odds: An Autobiography": {
        "domains": ["entrepreneurship", "engineering", "persistence", "biography"],
        "hint": "When facing entrenched competitors, iterating on product design, or needing inspiration for going against conventional wisdom in manufacturing or product.",
        "thesis": "James Dyson built a billion-dollar company through 5,127 failed prototypes. Conventional wisdom is usually wrong. Persistence through iteration, not genius insight, creates breakthroughs.",
    },
    "The Infinity Machine": {
        "domains": ["venture-capital", "technology", "Silicon-Valley", "finance"],
        "hint": "When thinking about venture capital dynamics, risk capital allocation, or how Silicon Valley's funding model shapes technology outcomes.",
        "thesis": "Venture capital is an infinity machine — a system designed to fund audacious bets that can change the world. Understanding how VCs think, evaluate, and compound returns shapes fundraising and capital strategy.",
    },
    "String Theory": {
        "domains": ["tennis", "writing", "observation", "essays"],
        "hint": "When thinking about mastery, observation, or the beauty of deeply watching someone perform at the highest level. Also a model for how to write about technical subjects with emotion.",
        "thesis": "David Foster Wallace's tennis essays show that watching mastery is itself a form of understanding. The body's intelligence, the physics of play, and the aesthetics of competition reveal truths that analysis alone misses.",
    },
    "Handbook of Pest Control (11th ed.)": {
        "domains": ["pest-control", "industry-reference", "operations"],
        "hint": "THE reference for pest control consolidation. Technical bible for the industry — use when evaluating pest control operations, understanding service delivery, or assessing operator competence.",
        "thesis": "The definitive technical reference for the pest control industry. Covers biology, treatment methods, regulations, and operational standards. Essential for anyone entering or consolidating in the space.",
    },
    "Sprint": {
        "domains": ["product", "design-thinking", "rapid-prototyping", "process"],
        "hint": "When needing to validate an idea in 5 days, design a prototype, or structure a rapid testing cycle for any business hypothesis.",
        "thesis": "You can answer critical business questions in just five days through structured sprints: map, sketch, decide, prototype, test. Speed of learning beats speed of building.",
    },
    "Continuous Discovery Habits": {
        "domains": ["product", "customer-research", "discovery", "process"],
        "hint": "When building product features and needing to validate with customers continuously, not just at launch. How to stay connected to what users actually need.",
        "thesis": "Product teams should discover and deliver simultaneously. Weekly customer touchpoints, opportunity solution trees, and assumption testing prevent building features nobody wants.",
    },
    "Ultralearning": {
        "domains": ["learning", "skill-acquisition", "self-improvement"],
        "hint": "When Santiago is learning a new skill (coding, padel, diving) and wants to optimize the learning curve. Meta-learning strategies.",
        "thesis": "Aggressive, self-directed learning projects can achieve in months what traditional education takes years to deliver. The key principles: metalearning, focus, directness, drill, retrieval, feedback, retention, intuition, experimentation.",
    },
    "Freakonomics": {
        "domains": ["economics", "incentives", "contrarian-thinking"],
        "hint": "When analyzing hidden incentives, questioning conventional wisdom, or looking for the non-obvious explanation behind behavior.",
        "thesis": "Incentives explain almost everything. The conventional explanation is usually wrong. Data reveals hidden patterns that morality and intuition miss. Ask 'what are people actually incentivized to do?'",
    },
    "Basic Statistical Methods": {
        "domains": ["statistics", "data", "methodology", "reference"],
        "hint": "When needing statistical fundamentals for data analysis, A/B testing, or evaluating claims with numbers.",
        "thesis": "Statistical methods are tools for reasoning under uncertainty. Mastering the basics — distributions, significance, correlation — prevents being fooled by data and enables evidence-based decisions.",
    },
    "What Is ChatGPT Doing ... and Why Does It Work?": {
        "domains": ["AI", "LLMs", "technology", "first-principles"],
        "hint": "When explaining or reasoning about how language models work under the hood. Technical foundation for AI product decisions.",
        "thesis": "Large language models work by predicting the next token using patterns learned from vast text corpora. Understanding the computational mechanics — neural nets, training, embeddings — demystifies AI and reveals its true capabilities and limits.",
    },
    "No Bullshit Guide to Linear Algebra": {
        "domains": ["mathematics", "linear-algebra", "AI", "reference"],
        "hint": "When needing linear algebra intuition for AI/ML understanding, data science, or any quantitative reasoning.",
        "thesis": "Linear algebra is the language of data, transformations, and machine learning. Vectors, matrices, eigenvalues — these aren't abstract math, they're the operating system of modern AI and engineering.",
    },
    "Wired to Create": {
        "domains": ["creativity", "psychology", "neuroscience"],
        "hint": "When thinking about creative process, idea generation, or why certain environments produce more innovation.",
        "thesis": "Creativity isn't a gift — it's a set of habits and mindsets that can be cultivated. The creative mind oscillates between focused and diffuse thinking, solitude and collaboration, openness and discipline.",
    },
    "The Coming Wave": {
        "domains": ["AI", "technology", "geopolitics", "existential-risk"],
        "hint": "When reasoning about AI regulation, biotech risks, or the geopolitical implications of emerging technology on Santiago's businesses.",
        "thesis": "AI and synthetic biology are the next great wave of technology — and unlike previous waves, they cannot be easily contained. The central challenge of our time is developing these technologies while maintaining some degree of control.",
    },
    "AI Superpowers": {
        "domains": ["AI", "China", "geopolitics", "technology"],
        "hint": "When analyzing US-China tech competition, AI adoption in different markets, or thinking about how AI transforms industries in emerging economies like Mexico.",
        "thesis": "China and the US are the two AI superpowers with fundamentally different approaches. China's advantage: data scale, government support, ruthless implementation. US advantage: foundational research, talent. The AI age will reshape global power.",
    },
    "The Technological Republic": {
        "domains": ["technology", "defense", "geopolitics", "Palantir"],
        "hint": "When thinking about technology's role in democratic defense, government tech adoption, or the ethics of building powerful analytical tools.",
        "thesis": "Democracies must embrace advanced technology — including AI and data analytics — or risk falling behind authoritarian regimes that will. The tech industry has a responsibility to serve democratic institutions, not just consumers.",
    },
    "Young China": {
        "domains": ["China", "demographics", "geopolitics", "culture"],
        "hint": "When analyzing Chinese market dynamics, understanding Chinese consumer behavior, or evaluating China-linked business opportunities like YUTE SHOES.",
        "thesis": "China's young generation is unlike any before it — shaped by the one-child policy, rapid urbanization, and internet culture. Understanding their values, aspirations, and consumer patterns is essential for anyone doing business with China.",
    },
    "Godel, Escher, Bach: An Eternal Golden Braid": {
        "domains": ["consciousness", "mathematics", "recursion", "systems", "first-principles"],
        "hint": "When reasoning about self-reference, emergent properties, consciousness, or the deep structure connecting math, art, and mind. The ultimate cross-domain thinking book.",
        "thesis": "Consciousness and meaning emerge from self-referential loops — strange loops — that exist in mathematics (Godel), art (Escher), and music (Bach). Intelligence is a pattern, not a substance.",
        "aliases": ["GEB", "Godel Escher Bach"],
    },
    "Deep Simplicity": {
        "domains": ["complexity", "chaos-theory", "emergence", "science"],
        "hint": "When thinking about why simple rules produce complex behavior, or how small changes cascade through systems (businesses, markets, ecosystems).",
        "thesis": "Complex systems emerge from simple rules. Chaos, fractals, and emergence aren't complications — they're the deep simplicity underlying weather, evolution, economies, and everything else.",
    },
    "The Evolution of Everything": {
        "domains": ["evolution", "decentralization", "bottom-up", "innovation"],
        "hint": "When arguing against top-down planning or for emergent solutions. Evolution as the universal algorithm — applies to technology, culture, economies, not just biology.",
        "thesis": "Evolution — bottom-up, decentralized trial and error — is the fundamental driver of change in everything: technology, morality, economics, culture. Top-down design is almost always inferior to evolutionary processes.",
    },
    "Decisive": {
        "domains": ["decision-making", "mental-models", "bias"],
        "hint": "When facing a difficult decision and wanting a structured process to avoid common decision traps. WRAP framework.",
        "thesis": "Decisions fail in predictable ways: narrow framing, confirmation bias, short-term emotion, overconfidence. The WRAP process — Widen options, Reality-test, Attain distance, Prepare to be wrong — systematically counters each failure mode.",
    },
    "Naked Statistics": {
        "domains": ["statistics", "data", "reasoning"],
        "hint": "When needing to reason about data, probability, or evaluate statistical claims in business context without getting lost in math.",
        "thesis": "Statistics is the science of learning from data. Intuition about distributions, significance, regression, and probability is more valuable than computational skill. Most bad decisions come from statistical illiteracy.",
    },
    "Naked Economics": {
        "domains": ["economics", "markets", "policy", "incentives"],
        "hint": "When reasoning about market dynamics, economic policy effects, trade, or why certain business environments exist the way they do.",
        "thesis": "Economics explains how the world actually works through incentives, trade-offs, and markets. Understanding basic economic principles — comparative advantage, externalities, price signals — prevents bad business and policy decisions.",
    },
    "The Next 100 Years": {
        "domains": ["geopolitics", "forecasting", "strategy"],
        "hint": "When thinking about long-term geopolitical trends, Mexico's strategic position, or how macro forces shape business environments over decades.",
        "thesis": "Geopolitical forecasting based on geographic, demographic, and technological constraints — not current events. The 21st century's power dynamics are predictable from structural factors, and Mexico's position is more strategic than most realize.",
    },
    "Numbers Don't Lie": {
        "domains": ["energy", "materials", "data", "reality-check"],
        "hint": "When needing hard data to reality-check an assumption about energy, food, technology, or economic scale. Smil is the antidote to hype.",
        "thesis": "Numbers ground speculation in reality. Vaclav Smil uses data to show what's actually true about energy, food production, materials, and innovation — cutting through narratives with quantitative analysis. Most popular claims about technology don't survive the numbers.",
    },
    "The ONE Thing": {
        "domains": ["focus", "productivity", "priority"],
        "hint": "When Santiago is spread across too many projects and needs to identify THE ONE THING. Already embedded in his /start routine.",
        "thesis": "Extraordinary results come from narrowing focus to the one thing that makes everything else easier or unnecessary. The focusing question: 'What's the ONE Thing I can do such that by doing it everything else will be easier or unnecessary?'",
    },
    "21 Lecciones para el Siglo XXI": {
        "domains": ["philosophy", "AI", "politics", "future"],
        "hint": "When thinking about how technology reshapes society, political systems, or human meaning in the age of AI.",
        "thesis": "The 21st century's biggest challenges — AI disruption, political polarization, meaning crisis — require new frameworks. Neither liberal nor nationalist narratives are adequate. Clarity of mind and meditation are the individual's best tools.",
        "aliases": ["21 Lessons for the 21st Century"],
    },
    "$100M Leads": {
        "domains": ["sales", "marketing", "lead-generation", "scaling"],
        "hint": "When building lead generation systems for any business — Pala Padel, Learning Gate, Tax Free. Volume 2 of Hormozi's playbook.",
        "thesis": "Leads are the lifeblood of any business. There are only a few ways to get them: warm outreach, cold outreach, content, paid ads, referrals, affiliates, employees, agencies. Master each channel, then combine them for compounding growth.",
    },
    "$100M Offers": {
        "domains": ["sales", "offers", "pricing", "value-creation"],
        "hint": "When designing pricing, offers, or value propositions for any product. THE reference for 'is this offer a no-brainer?' Hormozi's foundational playbook.",
        "thesis": "Grand Slam Offers are so good people feel stupid saying no. The value equation: Dream Outcome x Perceived Likelihood / Time Delay x Effort & Sacrifice. Stack value, not discounts. Make the offer, not the product, the competitive advantage.",
    },
    "$100M Money Models": {
        "domains": ["finance", "business-models", "unit-economics", "scaling"],
        "hint": "When modeling revenue, unit economics, or business financial architecture. How money actually flows in businesses that scale.",
        "thesis": "Business models are money machines. Understanding how revenue flows, where margins compound, and which models scale determines whether a business becomes a lifestyle company or a billion-dollar enterprise.",
    },
    "Data Science from Scratch (2nd ed.)": {
        "domains": ["data-science", "programming", "AI", "reference"],
        "hint": "When implementing data science techniques from first principles — not using libraries blindly but understanding what's happening underneath.",
        "thesis": "Data science is best learned by building every algorithm from scratch in Python. Understanding the math and logic behind ML models, statistics, and data processing prevents cargo-cult programming.",
    },
    "The Challenger Sale": {
        "domains": ["sales", "B2B", "enterprise-sales"],
        "hint": "When building B2B sales processes — especially for Learning Gate's enterprise sales or Cargo Claro's customs agency pitch. Teaching-based selling.",
        "thesis": "The best B2B salespeople don't build relationships first — they challenge customers' thinking. Teach, Tailor, Take Control. Insight-led selling creates urgency and differentiates on value, not price.",
    },
    "DotCom Secrets": {
        "domains": ["funnels", "digital-marketing", "online-business"],
        "hint": "When building sales funnels, landing pages, or digital customer journeys for any online product.",
        "thesis": "Every online business is a series of funnels. Value ladders guide customers from free to premium. Understanding funnel architecture — squeeze pages, tripwires, core offers, profit maximizers — is the foundation of digital commerce.",
    },
    "Expert Secrets": {
        "domains": ["authority", "storytelling", "marketing", "positioning"],
        "hint": "When positioning Santiago or any business as the authority in a space. How to build a mass movement around a product or idea.",
        "thesis": "Experts create movements by sharing their origin story, building frameworks, and creating new opportunities (not improvements). The Attractive Character + framework + movement = an audience that buys everything you create.",
    },
    "Traffic Secrets": {
        "domains": ["marketing", "traffic", "audience-building", "distribution"],
        "hint": "When needing to drive traffic to any digital product — Learning Gate, Pala Padel, or any new venture. Where to find customers online.",
        "thesis": "Traffic is people. Your dream customers already congregate somewhere — find those platforms, earn their attention through value, and redirect it to your funnels. Platform mastery beats paid ads for sustainable growth.",
    },
    "Gym Launch Secrets": {
        "domains": ["local-business", "operations", "sales", "scaling"],
        "hint": "When launching or scaling a local/physical business. Hormozi's original playbook — developed in gym trenches but applicable to any local service business.",
        "thesis": "Local businesses scale through irresistible offers, paid advertising with immediate ROI, and operational systems that don't depend on the owner. The gym launch model is a template for any local service business.",
    },
    "No B.S. Time Management for Entrepreneurs": {
        "domains": ["productivity", "time-management", "entrepreneurship"],
        "hint": "When Santiago's time is fragmented across too many businesses and he needs ruthless prioritization.",
        "thesis": "Entrepreneurs must value their time in dollars and ruthlessly eliminate anything below their hourly rate. Time vampires, meetings, and multitasking destroy entrepreneurial productivity. Guard time like money.",
    },
    "Ecosistemas Digitales: El Futuro de Todas las Industrias": {
        "domains": ["digital-ecosystems", "platform-business", "Mexico", "technology"],
        "hint": "When thinking about platform business models in Latin American context, digital transformation of traditional industries, or Mexico's tech landscape.",
        "thesis": "Every industry will be restructured as a digital ecosystem. Understanding platform dynamics, network effects, and digital transformation from a Latin American perspective is critical for building technology businesses in the region.",
        "aliases": ["Ecosistemas Digitales"],
    },
    "So Good They Can't Ignore You": {
        "domains": ["career", "skill-building", "deliberate-practice"],
        "hint": "When questioning whether to follow passion or build rare skills. The craftsman mindset vs passion mindset.",
        "thesis": "'Follow your passion' is bad advice. Career capital — rare and valuable skills built through deliberate practice — is what creates work you love. Passion follows mastery, not the other way around.",
    },
    "One to Many": {
        "domains": ["sales", "webinars", "presentations", "persuasion"],
        "hint": "When designing presentations, webinars, or any one-to-many selling format for Learning Gate, courses, or investor pitches.",
        "thesis": "The highest-leverage sales skill is presenting to many at once. Webinar architecture, slide psychology, and offer timing multiply revenue per hour of selling effort by 10-100x.",
    },
    "Exponential Organizations": {
        "domains": ["scaling", "technology", "organizational-design"],
        "hint": "When designing organizations that scale faster than traditional ones. The ExO model attributes — SCALE + IDEAS.",
        "thesis": "Exponential organizations use external resources (community, algorithms, staff-on-demand) and internal mechanisms (interfaces, dashboards, experimentation, autonomy, social technologies) to achieve output disproportionate to their size.",
    },
    "Crossing the Chasm (3rd ed.)": {
        "domains": ["product", "go-to-market", "adoption", "technology-marketing"],
        "hint": "When launching a tech product and facing the gap between early adopters and mainstream market — directly relevant to Learning Gate and Cargo Claro adoption.",
        "thesis": "Technology products must cross the chasm between visionary early adopters and pragmatic majority customers. The strategy: dominate a niche beachhead, then expand. Trying to sell to everyone at once kills most tech products.",
    },
    "Never Split the Difference": {
        "domains": ["negotiation", "communication", "psychology"],
        "hint": "When negotiating deals, partnerships, prices, or having difficult conversations with business partners. Tactical empathy and calibrated questions.",
        "thesis": "Negotiation is not rational — it's emotional. Tactical empathy, labeling emotions, calibrated questions ('How am I supposed to do that?'), and strategic silence get better outcomes than logic-based frameworks.",
    },
    "Double Your Profits": {
        "domains": ["finance", "cost-cutting", "profitability", "operations"],
        "hint": "When any business needs immediate profit improvement. 78 practical actions to cut costs and increase revenue.",
        "thesis": "Most businesses have 20-50% unnecessary costs hiding in plain sight. Systematic cost reduction — cutting every expense that doesn't directly drive revenue — doubles profits faster than growing revenue.",
    },
    "Oversubscribed": {
        "domains": ["demand", "scarcity", "marketing", "positioning"],
        "hint": "When a product or event needs to create demand exceeding supply — Pala Padel tournaments, Learning Gate cohorts, any launch.",
        "thesis": "The goal is to have more demand than you can fulfill. Oversubscribed businesses signal value, not chase customers. Build anticipation, signal scarcity, and make people compete to buy from you.",
    },
    "Get Better at Anything": {
        "domains": ["learning", "skill-acquisition", "practice"],
        "hint": "When optimizing learning approach for any new skill Santiago is acquiring — diving, coding, padel, photography.",
        "thesis": "Skill acquisition has universal principles: see (models), do (practice), feedback (correction). The three factors that determine learning speed are the quality of your models, the volume of your practice, and the directness of your feedback.",
    },
    "Wooden on Leadership": {
        "domains": ["leadership", "coaching", "character", "team-building"],
        "hint": "When building teams, coaching people, or thinking about leadership as character development rather than strategy.",
        "thesis": "Leadership is fundamentally about character and preparation, not charisma or strategy. John Wooden's Pyramid of Success — industriousness, enthusiasm, skill, team spirit, poise, confidence, competitive greatness — is built from the foundation up.",
    },
    "Inspired (2nd ed.)": {
        "domains": ["product", "product-management", "technology", "teams"],
        "hint": "When structuring product teams, running product discovery, or defining how product managers should work — relevant to Learning Gate and Cargo Claro product processes.",
        "thesis": "The best product teams discover and deliver simultaneously. Product managers exist to ensure the team builds the right product. Discovery techniques, empowered teams, and customer obsession separate the best tech companies from the rest.",
    },
    "Supercommunicators": {
        "domains": ["communication", "connection", "psychology"],
        "hint": "When Santiago needs to connect more deeply in conversations — business or personal. Addresses blind spot #4 (sharing only polished conclusions).",
        "thesis": "The best communicators match the type of conversation happening — practical, emotional, or social. They ask deep questions, recognize what kind of conversation they're in, and make others feel heard. Communication is a learnable skill, not a talent.",
    },
    "Poor Charlie's Almanack (Expanded 3rd ed.)": {
        "domains": ["mental-models", "investing", "wisdom", "multidisciplinary-thinking"],
        "hint": "THE mental models bible. When applying multidisciplinary thinking to any problem — business, investing, life. Munger is in Santiago's advisory board.",
        "thesis": "Worldly wisdom requires a latticework of mental models from multiple disciplines. Inversion, second-order thinking, incentive analysis, and avoiding psychological biases — these compound over a lifetime. The most important lesson: avoid being stupid rather than trying to be brilliant.",
        "aliases": ["Poor Charlies Almanack"],
    },
    "Bold Conjectures": {
        "domains": ["epistemology", "Popper", "Deutsch", "philosophy-of-science"],
        "hint": "When reasoning about knowledge creation, error correction, or applying Deutsch/Popper epistemology to business decisions.",
        "thesis": "Knowledge grows through bold conjectures and ruthless refutation. All knowledge is conjectural and improvable. The essays explore how Popperian epistemology applies to science, technology, and everyday reasoning.",
    },
    "Principles": {
        "domains": ["decision-making", "management", "systems", "culture"],
        "hint": "When building decision-making systems, organizational principles, or codifying how a company should operate. Dalio's radically transparent operating system.",
        "thesis": "Life and management operate on principles — fundamental truths that guide decision-making. Radical transparency, believability-weighted decision-making, and systematic error-correction create organizations that improve automatically.",
    },
    "The Blind Watchmaker": {
        "domains": ["evolution", "complexity", "design", "first-principles"],
        "hint": "When reasoning about how complex systems emerge without designers, or when challenging the assumption that complexity requires top-down planning.",
        "thesis": "Complex, apparently designed systems can emerge through cumulative selection without any designer. Evolution by natural selection is the blind watchmaker — producing the appearance of design through small, accumulated improvements over time.",
    },
    "The 33 Strategies of War": {
        "domains": ["strategy", "competition", "conflict", "power"],
        "hint": "When facing competitive battles, strategic positioning, or navigating adversarial business situations.",
        "thesis": "Strategic thinking from military history applied to everyday conflicts. Offensive, defensive, and unconventional strategies drawn from thousands of years of warfare — applicable to business competition, negotiation, and personal challenges.",
    },
    "Science and Human Values": {
        "domains": ["philosophy-of-science", "ethics", "creativity"],
        "hint": "When reasoning about the relationship between scientific thinking and ethical decision-making, or when the line between 'is' and 'ought' matters.",
        "thesis": "Science is not value-free — the act of discovery requires imagination, dissent, and respect for truth. The values that make science work (tolerance, honesty, independence) are the same values that make democracy work.",
    },
    "Flow: The Psychology of Optimal Experience": {
        "domains": ["psychology", "performance", "happiness", "focus"],
        "hint": "When optimizing for flow states — in coding, padel, piano, or any work. Understanding why Santiago's best work happens in specific conditions.",
        "thesis": "Happiness is not a goal but a byproduct of being fully absorbed in a challenging activity matched to your skill level. Flow states — the zone of optimal experience — are the key to both productivity and life satisfaction.",
    },
    "The Great Mental Models, Vol. 1: General Thinking Concepts": {
        "domains": ["mental-models", "thinking", "decision-making", "first-principles"],
        "hint": "When applying mental models to a specific decision — maps, first principles, second-order thinking, inversion, Occam's razor. Quick reference for structured reasoning.",
        "thesis": "Mental models are tools for understanding the world. The most useful ones — maps vs territory, circle of competence, first principles, thought experiments, second-order thinking, inversion — apply everywhere. Collect them like a toolkit.",
        "aliases": ["Great Mental Models Vol 1"],
    },
    "Thinking in Systems": {
        "domains": ["systems-thinking", "complexity", "feedback-loops", "mental-models"],
        "hint": "When analyzing any system — business operations, market dynamics, organizational behavior. Feedback loops, leverage points, and system archetypes.",
        "thesis": "Systems behave in predictable patterns driven by their structure, not by the intentions of the people in them. Stocks, flows, feedback loops, delays, and leverage points explain why well-intentioned interventions often backfire.",
    },
    "The 48 Laws of Power": {
        "domains": ["power", "strategy", "psychology", "influence"],
        "hint": "When navigating power dynamics in business relationships, partnerships, or competitive situations.",
        "thesis": "Power follows patterns observable across millennia. The 48 laws — never outshine the master, conceal your intentions, always say less than necessary, make others come to you — are amoral tools for understanding and navigating human power dynamics.",
    },
    "How to Win Friends & Influence People (Updated)": {
        "domains": ["communication", "influence", "relationships", "leadership"],
        "hint": "When Santiago needs to build rapport, influence stakeholders, or improve interpersonal effectiveness — particularly addresses blind spots #1 and #4.",
        "thesis": "Influence comes from genuine interest in others, not manipulation. The principles — become genuinely interested, smile, remember names, listen, talk about their interests, make them feel important — compound over a lifetime of relationships.",
    },
    "All I Want to Know Is Where I'm Going to Die So I'll Never Go There": {
        "domains": ["mental-models", "inversion", "wisdom", "Munger"],
        "hint": "When applying inversion thinking — what would guarantee failure? Avoid that. Pure Munger distillation.",
        "thesis": "Wisdom through inversion: instead of asking how to succeed, ask what guarantees failure and avoid it. Compiled from Munger and Buffett's teachings, this is the practical guide to avoiding stupidity — which is easier and more reliable than pursuing brilliance.",
    },
    "Science and Human Behavior": {
        "domains": ["behaviorism", "psychology", "management", "incentives"],
        "hint": "When designing incentive systems, understanding organizational behavior, or analyzing why people do what they do through a strict behavioral lens.",
        "thesis": "All human behavior is a function of its consequences. Skinner's behaviorist framework — reinforcement, punishment, extinction, schedules — explains and predicts behavior without reference to internal mental states. The most practical psychology book ever written.",
    },
    "Peak: Secrets from the New Science of Expertise": {
        "domains": ["deliberate-practice", "expertise", "performance", "learning"],
        "hint": "When structuring practice for any skill — padel, coding, piano, diving. The science behind 10,000 hours (and why the popular version is wrong).",
        "thesis": "Expertise comes from deliberate practice — not just repetition, but structured practice with immediate feedback, clear goals, and progressive difficulty. Mental representations — the expert's internal model — are what differentiate masters from amateurs.",
    },
    "The Charisma Myth": {
        "domains": ["charisma", "communication", "leadership", "presence"],
        "hint": "When Santiago needs to increase personal magnetism for pitches, leadership, or relationship building. Charisma as a learnable skill.",
        "thesis": "Charisma is not an innate gift — it's a set of learnable behaviors rooted in presence, power, and warmth. Internal state management (visualization, body language, cognitive reframing) drives external charisma. You can literally practice being magnetic.",
    },
    "How Will You Measure Your Life?": {
        "domains": ["life-design", "purpose", "relationships", "career"],
        "hint": "When Santiago is optimizing for achievement at the cost of relationships or meaning. Addresses the meta-instruction directly — building something meaningful while becoming someone capable of deep connection.",
        "thesis": "Apply business theories to life's most important decisions. Disruption theory explains career strategy. Job-to-be-done explains relationships. Process trumps outcome in raising children and building culture. The metrics for life success are different from business success.",
    },
    "Writing That Works": {
        "domains": ["writing", "communication", "business-writing"],
        "hint": "When writing needs to be clear, persuasive, and concise — emails, proposals, investor decks, product copy.",
        "thesis": "Good business writing is clear, concise, and reader-focused. Every word should work. Cut jargon, use active voice, organize for the reader's needs, and revise ruthlessly. Writing quality directly correlates with thinking quality.",
    },
    "Meditations": {
        "domains": ["stoicism", "philosophy", "leadership", "self-mastery"],
        "hint": "When facing adversity, managing emotions under pressure, or needing philosophical grounding for difficult decisions. The original leadership journal.",
        "thesis": "Marcus Aurelius's private journal on leading an empire while remaining virtuous. Focus on what you can control. Everything external is indifferent. Character and duty trump comfort. The obstacle is the way. Written 2,000 years ago, still the best leadership manual.",
    },
    "Letters from a Stoic": {
        "domains": ["stoicism", "philosophy", "wisdom", "practical-ethics"],
        "hint": "When needing practical wisdom for everyday challenges — wealth, friendship, adversity, death, anger. More accessible than Meditations for daily application.",
        "thesis": "Seneca's letters are practical philosophy for daily life. On wealth: use it, don't serve it. On time: it's the only non-renewable resource. On adversity: it's training, not punishment. On anger: the most destructive emotion. Stoicism as daily practice.",
    },
    "Cod: A Biography of the Fish That Changed the World": {
        "domains": ["trade", "history", "economics", "supply-chain"],
        "hint": "When thinking about how single commodities shape global trade, geopolitics, and economies — relevant to customs/trade businesses and understanding supply chain history.",
        "thesis": "A single fish species drove European exploration, colonization, and global trade for centuries. Cod shows how supply chains, trade routes, and entire economies organize around key commodities — and what happens when they collapse.",
    },
    "Carlos Slim": {
        "domains": ["biography", "Mexico", "business-strategy", "telecommunications"],
        "hint": "When studying Mexican business strategy, monopoly dynamics, or how to build massive wealth in emerging markets. The Mexican business playbook.",
        "thesis": "Carlos Slim built Latin America's largest fortune through disciplined acquisition during crises, monopoly positioning in telecommunications, and patient capital deployment. His strategy: buy undervalued assets, operate efficiently, and let compounding do the work.",
    },
    "Elon Musk": {
        "domains": ["biography", "entrepreneurship", "first-principles", "manufacturing"],
        "hint": "When reasoning about audacious goal-setting, manufacturing as moat, or managing multiple ventures simultaneously — directly relevant to Santiago's multi-business approach.",
        "thesis": "Elon Musk's biography reveals a pattern: first principles physics thinking applied to industries, manufacturing as the real competitive advantage, mission-driven urgency, and the willingness to absorb personal risk that would break most people.",
    },
    "Ask Iwata": {
        "domains": ["product", "leadership", "gaming", "empathy"],
        "hint": "When thinking about servant leadership, product intuition, or building things people love rather than things that are technically impressive.",
        "thesis": "Satoru Iwata led Nintendo by understanding what makes people happy, not what makes technology impressive. Programming background gave him empathy for creators. His leadership: listen, understand, serve — the opposite of top-down mandate.",
    },
    "The Changing World Order": {
        "domains": ["geopolitics", "economics", "history", "cycles"],
        "hint": "When analyzing macro trends, currency dynamics, or long-term geopolitical positioning. Where is the world heading and how does Mexico fit?",
        "thesis": "Great empires rise and fall in predictable cycles driven by debt, internal conflict, and external competition. The current US-China dynamic mirrors historical transitions of power. Understanding the cycle helps position businesses and investments for what's coming.",
    },
    "The Code Breaker": {
        "domains": ["biotech", "CRISPR", "innovation", "science"],
        "hint": "When thinking about biotech opportunities, the ethics of gene editing, or how scientific breakthroughs become commercial opportunities.",
        "thesis": "Jennifer Doudna's discovery of CRISPR is the story of how curiosity-driven science produces the most commercially transformative breakthroughs. The gene editing revolution will reshape medicine, agriculture, and what it means to be human.",
    },
    "Kissinger: A Biography": {
        "domains": ["diplomacy", "geopolitics", "power", "realpolitik"],
        "hint": "When navigating complex stakeholder relationships, practicing realpolitik in business, or understanding how power actually works between nations and institutions.",
        "thesis": "Kissinger practiced realpolitik — foreign policy based on practical power calculations rather than ideology. Understanding how he balanced competing interests, managed ambiguity, and pursued stability through pragmatism applies to any complex negotiation landscape.",
    },
    "1929": {
        "domains": ["finance", "crisis", "markets", "history"],
        "hint": "When reasoning about market bubbles, financial crises, or the psychology of collective delusion in markets.",
        "thesis": "The 1929 crash wasn't a surprise to those watching the fundamentals. Understanding how speculation, leverage, and collective delusion build to crisis helps recognize the same patterns in modern markets.",
    },
    "Mexico: A 500-Year History": {
        "domains": ["Mexico", "history", "culture", "geopolitics"],
        "hint": "When understanding Mexican institutional context, regulatory environment, or cultural dynamics that affect Santiago's businesses operating in Mexico.",
        "thesis": "Mexico's present is shaped by 500 years of colonial legacy, revolution, institutional development, and cultural synthesis. Understanding this history explains the regulatory environment, business culture, and opportunities that exist today.",
    },
    "Sapiens": {
        "domains": ["history", "anthropology", "cognitive-revolution", "first-principles"],
        "hint": "When reasoning about human nature, why institutions exist, or the fictional foundations of money, law, and corporations.",
        "thesis": "Homo sapiens dominated through the ability to create and believe in shared fictions — money, nations, corporations, religions. Understanding that all social structures are invented (and can be reinvented) is the deepest first-principles insight about human systems.",
    },
    "The Ascent of Man": {
        "domains": ["science-history", "civilization", "knowledge", "progress"],
        "hint": "When thinking about how knowledge compounds across generations, or how scientific progress drives civilizational advancement.",
        "thesis": "Human civilization is the story of knowledge compounding — each generation building on the discoveries of the last. Bronowski traces how hand, brain, and imagination drove humanity from stone tools to quantum physics. Knowledge is the true engine of progress.",
    },
}

# Books with minimal data (less well-known or niche)
MINIMAL_DATA = {
    "El Economista Mexicano (journals, vols. VII-X, ~1974)": {
        "domains": ["economics", "Mexico", "history", "reference"],
        "hint": "Historical Mexican economic journals. Reference for understanding Mexico's economic thinking in the 1970s.",
        "thesis": "A collection of Mexican economic journals from the 1970s, offering insight into the economic thinking and policy debates that shaped modern Mexico.",
    },
}


def slugify(title):
    s = title.lower()
    s = s.replace("$", "").replace("'", "").replace("'", "")
    s = s.replace(":", "").replace(",", "").replace(".", "")
    s = s.replace("(", "").replace(")", "")
    s = s.replace("&", "and")
    s = s.replace("  ", " ")
    s = re.sub(r"[^a-z0-9\s-]", "", s)
    s = re.sub(r"\s+", "-", s.strip())
    s = re.sub(r"-+", "-", s)
    s = s.strip("-")
    return s


def author_slug(author):
    name = author.split(" with ")[0].split(" & ")[0].split(",")[0]
    name = name.replace("ed. ", "").replace("(", "").replace(")", "")
    name = name.strip()
    return slugify(name)


def generate_book_page(num, title, author, publisher, notes):
    slug = slugify(title)
    data = BOOK_DATA.get(title, MINIMAL_DATA.get(title, None))

    if publisher is None:
        publisher = "Unknown"

    domains_str = "[]"
    hint = "Reference this book when its subject matter is relevant to Santiago's work or decisions."
    thesis = "To be filled on first deep reference or mirror creation."
    aliases_list = []

    if data:
        domains_str = str(data["domains"]).replace("'", '"')
        hint = data["hint"]
        thesis = data["thesis"]
        aliases_list = data.get("aliases", [])

    if notes and "Spanish" in str(notes):
        if "spanish" not in [d.lower() for d in (data or {}).get("domains", [])]:
            pass

    aliases_str = str(aliases_list).replace("'", '"') if aliases_list else "[]"

    a_slug = author_slug(author)

    page = f"""---
type: book
author: {author}
publisher: {publisher}
status: read
domains: {domains_str}
aliases: {aliases_str}
first_seen: {TODAY}
confidence: low
---
## For future Claude
{hint}

# {title}

Author: [[{a_slug}]]
Publisher: {publisher}

## Core Thesis
{thesis}

## Key Frameworks
- To be extracted on first reference or mirror creation

## Santiago's Applications
- To be connected as Santiago references this book in context of his work

## PDF
Not yet added — add to `books-pdf/{slug}.pdf` when available

## Timeline
- {TODAY}: Added to vault from book catalog (#{num})
"""
    return slug, page


def main():
    wb = openpyxl.load_workbook(
        os.path.expanduser("~/Downloads/book_catalog.xlsx")
    )
    ws = wb.active

    os.makedirs(ENTITIES_DIR, exist_ok=True)

    created = 0
    skipped = 0
    seen_slugs = set()

    for row in ws.iter_rows(min_row=2, values_only=True):
        num, title, author, publisher, notes = row
        if not title:
            continue

        slug, page = generate_book_page(num, title, author, publisher, notes)

        if slug in seen_slugs:
            print(f"  SKIP duplicate slug: {slug} ({title})")
            skipped += 1
            continue
        seen_slugs.add(slug)

        filepath = os.path.join(ENTITIES_DIR, f"{slug}.md")
        if os.path.exists(filepath):
            print(f"  EXISTS: {slug}.md")
            skipped += 1
            continue

        with open(filepath, "w") as f:
            f.write(page)
        print(f"  CREATED: {slug}.md")
        created += 1

    print(f"\nDone. Created: {created}, Skipped: {skipped}")


if __name__ == "__main__":
    main()
